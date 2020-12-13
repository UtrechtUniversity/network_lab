defmodule NetworkLab.GenServers.DatabaseAssistant do
    use GenServer

    alias NetworkLab.Repo

    require Logger

    # tick interval is every 0.01 seconds
    @tick_interval 10
    # pool size of database
    @pool_size Application.get_env(:network_lab, NetworkLab.Repo)[:pool_size] || 25
    
    def start_link(_) do
        GenServer.start_link(__MODULE__, :queue.new(), name: __MODULE__)
    end

    # add a changeset to the queue, <changeset> is a map containing the actual changeset
    # plus a flag that indicates if this is about inserting or updating
    def add(changeset) do
        GenServer.cast(__MODULE__, {:add, changeset})
    end

    # list the queue
    def get_queue() do
        GenServer.call(__MODULE__, :get_queue)
    end

    # reset the queue
    def flush() do
        GenServer.call(__MODULE__, :flush)
    end

    def init(queue) do
        tick(queue)
        {:ok, queue}
    end

    # handle adding to queue
    def handle_cast({ :add, changeset }, queue) do
        # add changeset to queue
        queue = :queue.in(changeset, queue)
        # return
        { :noreply, queue }
    end

    def handle_call(:flush, _payload, _queue) do
        { :reply, :ok, :queue.new()}
    end

    def handle_call(:get_queue, _payload, queue) do
        { :reply, :queue.to_list(queue), queue}
    end

    def handle_info(:tick, queue) do

        # how many elements are we going to remove, twice the size of pool_size to
        # make sure the database is pretty busy with handling race-condition-free jobs
        n = Enum.min([2 * @pool_size, :queue.len(queue)])

        # if we have more than 1 element:
        queue = if n > 0 do

            # remove <pool-size> elements in batch
            { batch, new_queue } = :queue.split(n, queue)
            # execute all elements in the batch: loop over queue items and check for potential
            # race conditions. The referee keeps track of what was executed and what needs to be 
            # send back to the queue
            referee_map = %{ passed_items: MapSet.new(), problem_cases: :queue.new()}
            # loop over 
            problems = Enum.reduce :queue.to_list(batch), referee_map, fn item, ref ->
                # create an identifier of the defstruct in the changeset of the item
                identifier = { item.changeset.data.id, item.changeset.data.__struct__ }
                # if this is a changeset we have already encountered, we put it back in front of the queue
                # to avoid race conditions
                if MapSet.member?(ref.passed_items, identifier) do
                    # put in referee queue, send back latter
                    %{ ref | problem_cases: :queue.in(item, ref.problem_cases) }
                else

                    try do
                        # execute the query
                        execute(item)
                    rescue
                        # log this exception
                        e -> Logger.error("!! Database Assistent: could not save item \n#{ inspect(item) }\n#{ inspect(e) }")
                    end

                    # and add to referee's passed items
                    %{ ref | passed_items: MapSet.put(ref.passed_items, identifier) }
                end
            end

            # return joined queue of problem cases (left-side, first to execute) and remaining queue
            :queue.join(problems.problem_cases, new_queue)
        else
            queue
        end

        # ask for the tick
        tick(queue)

        # and return async
        { :noreply, queue}
    end

    defp tick(queue) do
        # inform admin every 5 seconds
        now = NaiveDateTime.utc_now()
        seconds = now.second()
        { microseconds, _precision } = now.microsecond()
        # don't hit admin with too many notifications
        if rem(seconds, 5) == 0 and microseconds < 200_000 do
            NetworkLabWeb.Endpoint.broadcast("admin_channel", "update", %{ payload:
                %{ selector: "#queues span.db", contents: :queue.len(queue) }
            })
        end
        # wait @tick_interval seconds to continue
        Process.send_after(self(), :tick, @tick_interval)
    end

    # execute async with Repo
    defp execute(data) do
        case data.action do
            "insert" ->
                Repo.insert(data.changeset)
            "update" ->
                Repo.update(data.changeset)
        end
    end

end